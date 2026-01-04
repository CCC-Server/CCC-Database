-- 가비지 다이어그램
local s,id=GetID()
function s.initial_effect(c)
	-- "가비지 로드"의 카드명이 쓰여짐 (이 카드를 참조하는 다른 카드를 위해 설정)
	s.listed_names={44682448}

	-- ①: 자신 필드에 "가비지 로드" 또는 "가비지 로드"의 카드명이 쓰여진 몬스터가 존재할 경우, 이 카드는 패에서 특수 소환할 수 있다.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- ②: 자신 메인 페이즈에 발동할 수 있다. 서치 또는 특수 소환.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	-- [안전 수정] 턴 제약 표기 방식 호환성 고려
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-- ③: 이 카드를 소재로서 가지고 있는 엑시즈 몬스터는 이하의 효과를 얻는다.
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_XMATERIAL)
	e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e3:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e3:SetValue(aux.tgoval)
	c:RegisterEffect(e3)
end

-- "가비지 로드"의 코드
local CARD_GARBAGE_LORD = 44682448

-- [안전한 확인 함수] 가비지 로드가 기재되어 있는지 확인
function s.is_listed_safe(c)
	if not c then return false end
	-- 1. 코어 함수가 있으면 시도
	if c.IsCodeListed and c:IsCodeListed(CARD_GARBAGE_LORD) then return true end
	-- 2. Lua 테이블(listed_names)이 있으면 직접 확인 (커스텀 카드 호환)
	if c.listed_names then
		for _,code in ipairs(c.listed_names) do
			if code==CARD_GARBAGE_LORD then return true end
		end
	end
	return false
end

-- ① 효과 필터: "가비지 로드"이거나 "가비지 로드"의 카드명이 쓰여진 몬스터
function s.filter(c)
	return c:IsFaceup() and (c:IsCode(CARD_GARBAGE_LORD) or s.is_listed_safe(c))
end

-- ① 효과 조건
function s.spcon(e,c)
	if c==nil then return true end
	return Duel.GetLocationCount(c:GetControler(),LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.filter,c:GetControler(),LOCATION_MZONE,0,1,nil)
end

-- ② 효과 필터
function s.thfilter(c,e,tp,xyz_chk)
	if c:IsCode(id) then return false end -- "가비지 다이어그램" 이외
	if not c:IsMonster() then return false end -- 몬스터
	-- [수정됨] aux.IsCodeListed 대신 s.is_listed_safe 사용
	if not (c:IsCode(CARD_GARBAGE_LORD) or s.is_listed_safe(c)) then return false end 
	
	-- 패에 넣을 수 있거나, (엑시즈가 있고+특소 가능하며+공간이 있으면) 특소 가능해야 함
	local b1 = c:IsAbleToHand()
	local b2 = xyz_chk and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	return b1 or b2
end

-- ② 효과 Target
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- 자신 필드에 엑시즈 몬스터 확인
	local xyz_chk = Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsType,TYPE_XYZ),tp,LOCATION_MZONE,0,1,nil)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp,xyz_chk) end
	
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
	if xyz_chk then
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
	end
end

-- ② 효과 Operation
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local xyz_chk = Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsType,TYPE_XYZ),tp,LOCATION_MZONE,0,1,nil)
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp,xyz_chk)
	local tc=g:GetFirst()
	if tc then
		local b1 = tc:IsAbleToHand()
		local b2 = xyz_chk and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and tc:IsCanBeSpecialSummoned(e,0,tp,false,false)
		
		local op=0
		if b1 and b2 then
			op=Duel.SelectOption(tp,1190,1152) -- 1190: 패에 넣는다, 1152: 특수 소환한다
		elseif b1 then
			op=0
		elseif b2 then
			op=1
		else
			return
		end
		
		if op==0 then
			Duel.SendtoHand(tc,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,tc)
		else
			Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end