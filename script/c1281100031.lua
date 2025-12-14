-- 대괴수결전병기 - 3식 다목적 기룡
local s,id=GetID()
local COUNTER_KAIJU=0x37 -- 파괴수 카운터 ID
local CODE_OXYGEN=124161399 -- "대파괴수결전병기 - 옥시전 디스트로이어"의 카드 ID (작성 후 수정 필요)

function s.initial_effect(c)
	c:EnableReviveLimit()
	
	-- 특수 소환 절차 (패/묘지)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetCountLimit(2,id) -- 이 방법에 의한 소환은 1턴에 2번까지
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- ①: 특수 소환 성공 시 (서치)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-- ②: 릴리스 불가 및 소재 불가 (지속 효과)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetCode(EFFECT_UNRELEASABLE_SUM)
	e3:SetRange(LOCATION_MZONE)
	e3:SetValue(1)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_UNRELEASABLE_NONSUM)
	c:RegisterEffect(e4)
	-- 각종 소재 불가
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
	e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e5:SetValue(1)
	c:RegisterEffect(e5)
	local e6=e5:Clone()
	e6:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
	c:RegisterEffect(e6)
	local e7=e5:Clone()
	e7:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
	c:RegisterEffect(e7)
	local e8=e5:Clone()
	e8:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	c:RegisterEffect(e8)

	-- ③: 파괴수 카운터 제거 시 발동
	local e9=Effect.CreateEffect(c)
	e9:SetDescription(aux.Stringid(id,1))
	e9:SetCategory(CATEGORY_DESTROY+CATEGORY_TOHAND+CATEGORY_ATKCHANGE)
	e9:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e9:SetCode(EVENT_REMOVE_COUNTER+COUNTER_KAIJU) -- 파괴수 카운터 제거 감지
	e9:SetRange(LOCATION_MZONE)
	e9:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e9:SetCountLimit(1,id+1) -- ③ 효과는 1턴에 1번
	e9:SetTarget(s.rmtg)
	e9:SetOperation(s.rmop)
	c:RegisterEffect(e9)
end
s.listed_series={0xc82, 0xd3} -- 대괴수결전병기, 파괴수
s.listed_names={CODE_OXYGEN} -- 옥시전 디스트로이어
s.counter_list={COUNTER_KAIJU}

-- 특수 소환 조건: 필드에 파괴수 존재
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xd3) and c:IsType(TYPE_MONSTER)
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
end

-- ① 효과: 서치
function s.thfilter(c)
	return c:IsCode(CODE_OXYGEN) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- ③ 효과: 제거 or 바운스 + 공뻥
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() end
	if chk==0 then return Duel.IsExistingTarget(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	-- ev는 제거된 카운터 수입니다
	e:SetLabel(ev) 
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	
	-- 파괴 가능 여부와 패로 되돌리기 가능 여부 확인
	local b1=true -- 파괴는 기본적으로 가능하다고 가정 (실제로는 IsDestructable 체크가 자동 수행됨)
	local b2=tc:IsAbleToHand()
	local op=0
	
	if b1 and b2 then
		-- 선택: 0=파괴, 1=패로
		op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
	elseif b1 then
		op=0
	elseif b2 then
		op=1
	else
		return
	end
	
	local success=false
	if op==0 then
		if Duel.Destroy(tc,REASON_EFFECT)>0 then success=true end
	else
		if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then success=true end
	end
	
	-- 처리 성공 시 공격력 증가
	if success then
		local c=e:GetHandler()
		local count=e:GetLabel()
		if c:IsRelateToEffect(e) and c:IsFaceup() and count>0 then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(count*600)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
			c:RegisterEffect(e1)
		end
	end
end