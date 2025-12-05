--Fight Call - Afterburner
local s,id=GetID()

-- 세트 상수
local SET_AEROMANEUVER=0xc49   -- "Aero Maneuver"
local SET_FIGHTCALL=0xc50	  -- "Fight Call"

function s.initial_effect(c)
	-- 카드군 표기용
	s.listed_series={SET_AEROMANEUVER,SET_FIGHTCALL}

	--------------------------------
	-- (1) 발동 : "Aero Maneuver" 몬스터 서치 후,
	--			(선택) 자신 카드 1장 패로
	--	  이 카드명 카드는 1턴에 최대 2번까지 발동 가능
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	-- 이 카드명 카드는 1턴에 2번까지 발동 가능
	e1:SetCountLimit(2,id)
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)

	--------------------------------
	-- (2) 카드 효과로 파괴되었을 때, 자신을 세트
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_DESTROYED)
	e2:SetCondition(s.setcon)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end

--------------------------------
-- (1) 서치용 필터 : 덱의 "Aero Maneuver" 몬스터
--------------------------------
function s.amfilter(c)
	return c:IsSetCard(SET_AEROMANEUVER)
		and c:IsMonster()
		and c:IsAbleToHand()
end

function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.amfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.actop(e,tp,eg,ep,ev,re,r,rp)
	-- 1) "Aero Maneuver" 몬스터 1장 서치
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.amfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		if Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,g)
			-- 2) 그 후, (선택) 자신 필드의 카드 1장 패로 되돌림
			if Duel.IsExistingMatchingCard(Card.IsAbleToHand,tp,LOCATION_ONFIELD,0,1,nil)
				and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
				local rg=Duel.SelectMatchingCard(tp,Card.IsAbleToHand,tp,LOCATION_ONFIELD,0,1,1,nil)
				if #rg>0 then
					Duel.SendtoHand(rg,nil,REASON_EFFECT)
				end
			end
		end
	end
end

--------------------------------
-- (2) 파괴되었을 때 세트
--------------------------------
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 카드 효과로 파괴되었고, 이전에 SZONE에 있었을 때
	return c:IsReason(REASON_EFFECT) and c:IsPreviousLocation(LOCATION_SZONE)
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and e:GetHandler():IsSSetable()
	end
	Duel.SetOperationInfo(0,0,e:GetHandler(),1,0,0)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.SSet(tp,c)
end
