--Blizzard Fusion
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Fusion.CreateSummonEff{
		handler=c,
		fusfilter=s.fusfilter,
		matfilter=s.matfilter,
		extrafil=s.fextra,
		extraop=s.extraop,
		stage2=s.stage2
	}
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e1)
end

--엑스트라 덱 특소 제한 (융합 몬스터만)
function s.stage2(e,tc,tp,mg,chk)
	-- 소환에 성공하면 발동턴 특소제약 걸기
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetTargetRange(1,0)
	e1:SetTarget(function(e,c)
		return c:IsLocation(LOCATION_EXTRA) and not c:IsType(TYPE_FUSION)
	end)
	Duel.RegisterEffect(e1,tp)
end

-- 융합 소환 가능한 몬스터 범위: "블리자드 프린세스" 융합 몬스터만
function s.fusfilter(c)
	return c:IsSetCard(0x757) and c:IsType(TYPE_FUSION)
end

-- 기본 융합 소재: 패/필드 몬스터
function s.matfilter(c,e,tp)
	return c:IsLocation(LOCATION_HAND+LOCATION_MZONE)
end

-- 덱에서 소재 추가 (조건: 블리자드 프린세스 필드에 존재)
function s.fextra(e,tp,mg)
	if Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,28348537),tp,LOCATION_MZONE,0,1,nil) then
		return Duel.GetMatchingGroup(s.fcheck,tp,LOCATION_DECK,0,nil),s.extraval
	end
	return nil,nil
end
function s.fcheck(c)
	return c:IsSetCard(0x757) and c:IsAbleToGrave()
end

-- 덱에서 넣은 소재는 무조건 묘지로 보내기
function s.extraval(e,c)
	return true
end

-- 덱소재가 선택된 경우 묘지로 보내는 처리
function s.extraop(e,tc,tp,sg)
	local g=sg:Filter(Card.IsLocation,nil,LOCATION_DECK)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	end
end
