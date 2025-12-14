--World Guardian - World of Grace
local s,id=GetID()
function s.initial_effect(c)
	--------------------------------------------------
	-- (Activate) + (1) 발동시 서치
	--------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0)) -- "When this card is activated..." 텍스트용
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	-- "이 카드명의 카드는 1턴에 1번만 발동할 수 있다."
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)
	
	--------------------------------------------------
	-- (2) 월가 몬스터 존재 시, 월가 몬스터 대상 내성 + 500/500
	--------------------------------------------------
	-- 대상 내성
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetCondition(s.protcon)
	e2:SetTarget(s.prottg)
	e2:SetValue(aux.tgoval) -- 상대 효과에만 대상 내성
	c:RegisterEffect(e2)
	-- ATK +500
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetRange(LOCATION_FZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetCondition(s.protcon)
	e3:SetTarget(s.prottg)
	e3:SetValue(500)
	c:RegisterEffect(e3)
	-- DEF +500
	local e4=e3:Clone()
	e4:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e4)
	
	--------------------------------------------------
	-- (3) 상대에 의해 월가 몬스터가 필드에서 떠났을 때 특소
	--------------------------------------------------
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e5:SetCode(EVENT_LEAVE_FIELD)
	e5:SetRange(LOCATION_FZONE)
	e5:SetProperty(EFFECT_FLAG_DELAY)
	-- "이 카드명의 (3) 효과는 1턴에 1번만 사용할 수 있다."
	e5:SetCountLimit(1,{id,2})
	e5:SetCondition(s.spcon3)
	e5:SetTarget(s.sptg3)
	e5:SetOperation(s.spop3)
	c:RegisterEffect(e5)
end

--------------------------------------------------
-- (1) When this card is activated: 월가 몬스터 서치
--------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(0xc52) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- "발동" 자체는 항상 가능, 서치는 있으면 처리
	if chk==0 then return true end
	if Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) then
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	end
end
function s.actop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	if not Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) then return end
	-- "You can" 이라 선택 가능
	if Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	end
end

--------------------------------------------------
-- (2) 월가 몬스터 존재 + 월가 몬스터 버프/내성
--------------------------------------------------
function s.cmonfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc52) and c:IsType(TYPE_MONSTER)
end
-- "While you control a 'World Guardian' monster"
function s.protcon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.IsExistingMatchingCard(s.cmonfilter,tp,LOCATION_MZONE,0,1,nil)
end
-- "World Guardian" monsters you control
function s.prottg(e,c)
	return c:IsSetCard(0xc52) and c:IsType(TYPE_MONSTER)
end

--------------------------------------------------
-- (3) 상대에 의해 내가 컨트롤하던 월가 몬스터가 필드를 떠났을 때
--	 → 다른 이름의 월가 몬스터를 덱/묘지에서 특소
--------------------------------------------------
-- 필드를 떠난 "World Guardian" 몬스터(내가 컨트롤, 상대에 의해)
function s.leavefilter(c,tp)
	return c:IsPreviousControler(tp)
		and c:IsPreviousLocation(LOCATION_MZONE)
		and c:IsSetCard(0xc52) and c:IsType(TYPE_MONSTER)
		and (c:IsReason(REASON_EFFECT) or c:IsReason(REASON_BATTLE))
		and c:GetReasonPlayer()==1-tp
end

function s.spcon3(e,tp,eg,ep,ev,re,r,rp)
	-- 내 월가 몬스터가 상대에 의해 필드를 떠난 경우가 있는가
	return eg:IsExists(s.leavefilter,1,nil,tp)
end

-- 덱/묘지에서 특소할 대상: 떠난 몬스터들과 "다른 이름"
function s.spfilter3(c,e,tp,lg)
	return c:IsSetCard(0xc52) and c:IsType(TYPE_MONSTER)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and not lg:IsExists(Card.IsCode,1,nil,c:GetCode())
end

function s.sptg3(e,tp,eg,ep,ev,re,r,rp,chk)
	local lg=eg:Filter(s.leavefilter,nil,tp) -- 이번에 나간 내 월가 몬스터들
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter3,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp,lg)
	end
	lg:KeepAlive()
	e:SetLabelObject(lg)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.spop3(e,tp,eg,ep,ev,re,r,rp)
	local lg=e:GetLabelObject()
	if not lg then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		lg:DeleteGroup()
		return
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter3,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp,lg)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
	lg:DeleteGroup()
end
